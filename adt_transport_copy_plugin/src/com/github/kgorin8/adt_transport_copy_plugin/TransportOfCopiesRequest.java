package com.github.kgorin8.adt_transport_copy_plugin;

import java.net.HttpURLConnection;

import java.net.URI;

import org.eclipse.core.resources.IProject;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.viewers.ITreeSelection;
import org.eclipse.ui.IWorkbenchWindow;
import org.eclipse.ui.PlatformUI;

import com.github.kgorin8.adt_transport_copy_plugin.RequestAction;
import com.sap.adt.communication.message.HeadersFactory;
import com.sap.adt.communication.message.IHeaders;
import com.sap.adt.communication.message.IResponse;
import com.sap.adt.communication.message.IResponse.IErrorInfo;
import com.sap.adt.communication.resources.AdtRestResourceFactory;
import com.sap.adt.communication.resources.IRestResource;
import com.sap.adt.compatibility.discovery.AdtDiscoveryFactory;
import com.sap.adt.compatibility.discovery.IAdtDiscovery;
import com.sap.adt.compatibility.discovery.IAdtDiscoveryCollectionMember;
import com.sap.adt.compatibility.model.templatelink.IAdtTemplateLink;
import com.sap.adt.compatibility.uritemplate.IAdtUriTemplate;
import com.sap.adt.destinations.ui.logon.AdtLogonServiceUIFactory;
import com.sap.adt.project.IAdtCoreProject;
import com.sap.adt.project.ui.util.ProjectUtil;
import com.sap.adt.tm.IRequest;
import com.sap.adt.tools.core.project.IAbapProject;

import org.eclipse.ui.console.ConsolePlugin;
import org.eclipse.ui.console.MessageConsole;
import org.eclipse.ui.console.MessageConsoleStream;
import org.eclipse.ui.console.IConsoleManager;
import org.eclipse.ui.console.IConsole;

public class TransportOfCopiesRequest {
	private IWorkbenchWindow window;
	private ITreeSelection selection;
	private RequestAction requestAction;
	private String transportNumber;
	private static final String URI_DISCOVERY_STATIC = "/sap/bc/adt/discovery";
	private static final String URI_RESOURCE_SCHEME = "http://github.com/kgorin8/adt_transport_copy_plugin";
	private static final String URI_RESOURCE_TERM = "toc";
	private static final String URI_RESOURCE_TEMPLATE = "http://github.com/kgorin8/adt_transport_copy_plugin/toc/create";
	private static final String URI_PARAMETER_TRANSPORT = "transport";
	private static final String URI_PARAMETER_ACTION = "action";
	private static final String URI_PARAMETER_ACTION_CREATE = "create";
	private static final String URI_PARAMETER_ACTION_RELEASE = "release";

	private MessageConsole findConsole(String name) {
		ConsolePlugin plugin = ConsolePlugin.getDefault();
		IConsoleManager conMan = plugin.getConsoleManager();
		IConsole[] existing = conMan.getConsoles();
		for (int i = 0; i < existing.length; i++)
			if (name.equals(existing[i].getName()))
				return (MessageConsole) existing[i];
		// no console found, so create a new one
		MessageConsole myConsole = new MessageConsole(name, null);
		conMan.addConsoles(new IConsole[] { myConsole });
		return myConsole;
	}

	private void log(String text) {
		MessageConsole myConsole = findConsole("ADT Transport Utils");
		MessageConsoleStream out = myConsole.newMessageStream();
		out.println(text);
	}

	public TransportOfCopiesRequest(IWorkbenchWindow window, ITreeSelection selection, RequestAction releaseRequest) {
		this.window = window;
		this.selection = selection;
		this.requestAction = releaseRequest;
		IRequest transportRequest = (IRequest) this.selection.getFirstElement();
		this.transportNumber = transportRequest.getNumber();

	}

	public void executePost() {
		String destination = this.getAbapProjectDestination();
		URI tocResourceUri = this.getResourceUri(destination);

		if (tocResourceUri != null) {
			this.log("Trying destination " + destination + " and URL " + tocResourceUri);
			this.executePost(destination, tocResourceUri);
		} else {		
			MessageDialog.openError(this.window.getShell(), "ADT Transport of Copies",
					"Necessary backend endpoint " + destination
					+ " could not be found. Install and configure ABAP part.");

		}
	}

	private void executePost(String destination, URI tocResourceUri) {
		IRestResource tocRessource = AdtRestResourceFactory.createRestResourceFactory()
				.createResourceWithStatelessSession(tocResourceUri, destination);

		IHeaders requestHeader = HeadersFactory.newHeaders();

		try {
			IResponse response = tocRessource.post(null, requestHeader, IResponse.class, null, null);
			int status = response.getStatus();

			this.log("Got response from ABAP backend " + response.getStatusLine());

			if (status != HttpURLConnection.HTTP_OK) {
				IErrorInfo errorInfo = response.getErrorInfo();
				MessageDialog.openError(this.window.getShell(), "ADT Transport of Copies",
						"An error occured: "
								+ errorInfo.getMessage());
			}
		} catch (RuntimeException e) {
			MessageDialog.openError(this.window.getShell(), "ADT Transport of Copies",
					"An exception occured: " + e.getMessage());
		}

	}

	private String getAbapProjectDestination() {
		IProject project = ProjectUtil.getActiveAdtCoreProject(this.selection, null, null,
				IAdtCoreProject.ABAP_PROJECT_NATURE);
		IAbapProject abapProject = (IAbapProject) project.getAdapter(IAbapProject.class);
		AdtLogonServiceUIFactory.createLogonServiceUI().ensureLoggedOn(abapProject.getDestinationData(),
				PlatformUI.getWorkbench().getProgressService());
		String destination = abapProject.getDestinationId();
		return destination;
	}

	private URI getResourceUri(String destination) {
		String uri = null;

		IAdtDiscovery discovery = AdtDiscoveryFactory.createDiscovery(destination, URI.create(URI_DISCOVERY_STATIC));

		IAdtDiscoveryCollectionMember collectionMember = discovery.getCollectionMember(URI_RESOURCE_SCHEME,
				URI_RESOURCE_TERM, new NullProgressMonitor());
		
		if (collectionMember == null) return null;
		
		IAdtTemplateLink templateLink = collectionMember.getTemplateLink(URI_RESOURCE_TEMPLATE);
		IAdtUriTemplate uriTemplate = templateLink.getUriTemplate();

		if (this.requestAction == RequestAction.Create) {
			uri = uriTemplate.set(URI_PARAMETER_TRANSPORT, this.transportNumber)
					.set(URI_PARAMETER_ACTION, URI_PARAMETER_ACTION_CREATE).expand();
		} else if (this.requestAction == RequestAction.Release) {
			uri = uriTemplate.set(URI_PARAMETER_TRANSPORT, this.transportNumber)
					.set(URI_PARAMETER_ACTION, URI_PARAMETER_ACTION_RELEASE).expand();
		}

		return URI.create(uri);

	}
}
